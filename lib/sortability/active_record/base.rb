module Sortability
  module ActiveRecord
    module Base
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Defines methods that are used to sort records
        # Use via sortable_belongs_to or sortable_class
        def sortable_methods(**options)
          on = options[:on] || :sort_position
          container = options[:container]
          inverse_of = options[:inverse_of]
          scope_array = [options[:scope]].flatten.compact
          onname = on.to_s
          setter_mname = "#{onname}="
          peers_mname = "#{onname}_peers"
          before_validation_mname = "#{onname}_before_validation"
          next_by_mname = "next_by_#{onname}"
          prev_by_mname = "previous_by_#{onname}"
          compact_peers_mname = "compact_#{onname}_peers!"

          class_exec do
            before_validation before_validation_mname.to_sym

            # Returns all the sort peers for this record, including self
            define_method peers_mname do |force_scope_load = false|
              unless force_scope_load || container.nil? || inverse_of.nil?
                cont = send(container)
                return cont.send(inverse_of) unless cont.nil?
              end

              relation = self.class.unscoped
              scope_array.each do |s|
                relation = relation.where(s => send(s))
              end
              relation
            end

            # Assigns the "on" field's value if needed
            # Adds 1 to any conflicting fields
            define_method before_validation_mname do
              val = send(on)
              scope_changed = scope_array.any? { |s|
                                !changed_attributes[s].nil? }

              return unless val.nil? || scope_changed || changes[on]

              peers = send(peers_mname, scope_changed)
              if val.nil?
                # Assign the next available number to the record
                max_val = (peers.loaded? ? \
                            peers.to_a.max_by{|r| r.send(on) || 0}.try(on) : \
                            peers.maximum(on)) || 0
                send(setter_mname, max_val + 1)
              elsif peers.to_a.any? { |p| p != self && p.send(on) == val }
                # Make a gap for the record
                at = self.class.arel_table
                peers.where(at[on].gteq(val))
                     .reorder(nil)
                     .update_all("#{onname} = - (#{onname} + 1)")
                peers.where(at[on].lt(0))
                     .reorder(nil)
                     .update_all("#{onname} = - #{onname}")

                # Cause peers to load from the DB the next time they are used
                peers.reset
              end
            end

            # Gets the next record among the peers
            define_method next_by_mname do
              val = send(on)
              peers = send(peers_mname)
              peers.loaded? ? \
                peers.to_a.detect { |p| p.send(on) > val } : \
                peers.where(peers.arel_table[on].gt(val)).first
            end

            # Gets the previous record among the peers
            define_method prev_by_mname do
              val = send(on)
              peers = send(peers_mname)
              peers.loaded? ? \
                peers.to_a.reverse.detect { |p| p.send(on) < val } : \
                peers.where(peers.arel_table[on].lt(val)).last
            end

            # Renumbers the peers so that their numbers are sequential,
            # starting at 1
            define_method compact_peers_mname do
              needs_update = false
              peers = send(peers_mname)
              cases = peers.to_a.collect.with_index do |p, i|
                old_val = p.send(on)
                new_val = i + 1
                needs_update = true if old_val != new_val

                # Make sure "on" field in self is up to date
                send(setter_mname, new_val) if p == self

                "WHEN #{old_val} THEN #{- new_val}"
              end.join(' ')

              return peers unless needs_update

              mysql = \
                defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter) && \
                ActiveRecord::Base.connection.instance_of?(
                  ActiveRecord::ConnectionAdapters::MysqlAdapter)
              cend = mysql ? 'END CASE' : 'END'

              self.class.transaction do
                peers.reorder(nil)
                     .update_all("#{onname} = CASE #{onname} #{cases} #{cend}")
                peers.reorder(nil).update_all("#{onname} = - #{onname}")
              end

              # Mark self as not dirty
              changes_applied
              # Force peers to load from the DB the next time they are used
              peers.reset
            end
          end
        end

        # Defines a sortable has_many relation on the container
        def sortable_has_many(records, scope_or_options = nil, **remaining_options, &extension)
          scope, options = extract_association_params(scope_or_options, remaining_options)
          if scope.nil?
            on = options[:on] || :sort_position
            scope = -> { order(on) }
          end

          class_exec { has_many records, scope, **options.except(:on), &extension }
        end

        # Defines a sortable belongs_to relation on the child records
        def sortable_belongs_to(container, scope_or_options = nil,
                                **remaining_options, &extension)
          scope, options = extract_association_params(scope_or_options, remaining_options)
          on = options[:on] || :sort_position

          class_exec do
            belongs_to container, scope, **options.except(:on, :scope), &extension

            reflection = reflect_on_association(container)
            options[:scope] ||= reflection.polymorphic? ? \
                                  [reflection.foreign_type,
                                   reflection.foreign_key] : \
                                  reflection.foreign_key
            options[:inverse_of] ||= reflection.inverse_of.try(:name)

            validates on, presence: true,
                          numericality: { only_integer: true,
                                          greater_than: 0 },
                          uniqueness: { scope: options[:scope] }
          end

          options[:container] = container
          sortable_methods(**options)
        end

        # Defines a sortable class without a container
        def sortable_class(**options)
          on = options[:on] || :sort_position
          scope = options[:scope]

          class_exec do
            default_scope { order(on) }

            validates on, presence: true,
                          numericality: { only_integer: true,
                                          greater_than: 0 },
                          uniqueness: (scope.nil? ? true : { scope: scope })
          end

          sortable_methods(**options)
        end

        protected

        def extract_association_params(scope_or_options, remaining_options)
          if scope_or_options.is_a?(Hash)
            [nil, scope_or_options.merge(remaining_options)]
          else
            [scope_or_options, remaining_options]
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Sortability::ActiveRecord::Base

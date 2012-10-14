require 'set'
require 'audited/audit'

module Audited
	module Adapters
		module ActiveRecord
			# Audit saves the changes to ActiveRecord models.  It has the following attributes:
			#
			# * <tt>auditable</tt>: the ActiveRecord model that was changed
			# * <tt>user</tt>: the user that performed the change; a string or an ActiveRecord model
			# * <tt>action</tt>: one of create, update, or delete
			# * <tt>audited_changes</tt>: a serialized hash of all the changes
			# * <tt>comment</tt>: a comment set with the audit
			# * <tt>created_at</tt>: Time that the change was performed
			#
			class Audit < ::ActiveRecord::Base
				include Audited::Audit

				serialize :audited_changes

				belongs_to :user
				after_create :send_notification, :send_mail

				default_scope         order(:version)
				scope :descending,    reorder("version DESC")
				scope :creates,       :conditions => {:action => 'create'}
				scope :updates,       :conditions => {:action => 'update'}
				scope :destroys,      :conditions => {:action => 'destroy'}

				scope :up_until,      lambda {|date_or_time| where("created_at <= ?", date_or_time) }
				scope :from_version,  lambda {|version| where(['version >= ?', version]) }
				scope :to_version,    lambda {|version| where(['version <= ?', version]) }

				# Return all audits older than the current one.
				def ancestors
					self.class.where(['auditable_id = ? and auditable_type = ? and version <= ?',
						auditable_id, auditable_type, version])
				end

				# Allows user to be set to either a string or an ActiveRecord object
				# @private
				def user_as_string=(user)
					# reset both either way
					self.user_as_model = self.username = nil
					user.is_a?(::ActiveRecord::Base) ?
						self.user_as_model = user :
						self.username = user
				end
				alias_method :user_as_model=, :user=
				alias_method :user=, :user_as_string=

				# @private
				def user_as_string
					self.user_as_model || self.username
				end
				alias_method :user_as_model, :user
				alias_method :user, :user_as_string
			private

				# Sends push notification
				def send_notification
					if self.user_id.nil? == false
						Pusher['test_channel'].trigger('greet', {:greeting => self.user.name.to_s + ' ' + self.action.to_s + ' ' + self.auditable_type.to_s + ' with ID:' + self.auditable_id.to_s})
					end
				end

				# Sends email
				def send_mail
					if self.user_id.nil? == false
						if self.auditable_type != 'User'
							if self.action == 'create'
								AuditMailer.audit_created(self.user_id, self).deliver
							    elsif self.action == 'update'
								AuditMailer.audit_updated(self.user_id, self).deliver
							    elsif self.action == 'destroy'
								AuditMailer.audit_destroyed(self.user_id, self).deliver
							    else

							end
						end
					end
				end

				def set_version_number
					max = self.class.maximum(:version,
						:conditions => {
							:auditable_id => auditable_id,
							:auditable_type => auditable_type
						}) || 0
					self.version = max + 1
				end
			end
		end
	end
end

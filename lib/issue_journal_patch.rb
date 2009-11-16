
require 'issue'

module IssueJournalPatch
  def self.included(base) # :nodoc:
    base.class_eval do

      # Saves the changes in a Journal
      # Called after_save
      def create_journal
        if @current_journal
          # attributes changes
          (Issue.column_names - %w(id description lock_version created_on updated_on)).each {|c|
            @current_journal.details << JournalDetail.new(:property => 'attr',
                                                          :prop_key => c,
                                                          :old_value => @issue_before_change.send(c),
                                                          :value => send(c)) unless send(c)==@issue_before_change.send(c) ||
                         @current_journal.details.exists?(:property => 'attr',
                                                          :prop_key => c,
                                                          :old_value => @issue_before_change.send(c),
                                                          :value => send(c))
          }
          # custom fields changes
          custom_values.each {|c|
            next if (@custom_values_before_change[c.custom_field_id]==c.value ||
                      (@custom_values_before_change[c.custom_field_id].blank? && c.value.blank?)) ||
                         @current_journal.details.exists?(:property => 'cf', 
                                                          :prop_key => c.custom_field_id,
                                                          :old_value => @custom_values_before_change[c.custom_field_id],
                                                          :value => c.value)
            @current_journal.details << JournalDetail.new(:property => 'cf', 
                                                          :prop_key => c.custom_field_id,
                                                          :old_value => @custom_values_before_change[c.custom_field_id],
                                                          :value => c.value)
          }      
          @current_journal.save
        end
      end

    end
  end
end

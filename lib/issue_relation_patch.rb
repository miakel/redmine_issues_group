require 'issue'
require 'awesome_nested_set'

module IssueRelationPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      acts_as_nested_set
    end
  end

  module InstanceMethods
    # Returns nil if there is no 'precedes' relationship to the parent issue
    def precedes?(issue)
      return if issue.nil?
      !relations_from.detect {|r| r.relation_type == 'precedes' && r.issue_to_id == issue.id}.nil?
    end

    # Returns the relation object of the precedent if this issue precedes 'issue'
    # Otherwise, create a 'precedes' relationship between this issue and 'issue'
    def precedes(issue)
      return if issue.nil?
      if self.precedes?(issue)
        relations_from.detect {|r| r.relation_type == 'precedes' && r.issue_to_id == issue.id}
      else
        IssueRelation.new(:relation_type => 'precedes', :issue_from => self, :issue_to => issue).save
      end
    end
    
  end
end

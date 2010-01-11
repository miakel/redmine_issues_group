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
    # Returns nil if there is no 'blocks' relationship to the parent issue
    def blocks?(issue)
      return if issue.nil?
      !relations_from.detect {|r| r.relation_type == 'blocks' && r.issue_to_id == issue.id}.nil?
    end

    # Returns the relation object of the blocks if this issue blocks 'issue'
    # Otherwise, create a 'blocks' relationship between this issue and 'issue'
    def blocks(issue)
      return if issue.nil?
      if self.blocks?(issue)
        relations_from.detect {|r| r.relation_type == 'blocks' && r.issue_to_id == issue.id}
      else
        IssueRelation.new(:relation_type => 'blocks', :issue_from => self, :issue_to => issue).save
      end
    end
    
  end
end

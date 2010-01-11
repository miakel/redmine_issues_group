require 'redmine'
require_dependency 'issues_controller' 

class IssuesController < ApplicationController
  skip_before_filter :authorize, :only => [:autocomplete_for_parent]
  prepend_before_filter :find_all_issues, :only => [:parent_edit, :copy_subissue] #:authorize,
  before_filter :authorize, :except => [:index, :changes, :gantt, :calendar, :preview, :update_form, :context_menu]

  def autocomplete_for_parent
    @issues = Issue.find(:all, :conditions => ["LOWER(subject) LIKE ? OR id LIKE ?", "%#{params[:text]}%", "%#{params[:text]}%"],
                              :limit => 10,
                              :order => 'id ASC').uniq
    render :layout => false
  end
  def parent_edit
    if request.post?
      if params[:parent]
        i = Issue.find_by_id(params[:parent]) rescue nil unless params[:parent].empty? 
        @project = i.nil? ? nil : i.project 
        if @issues.include?(i)
          flash[:error] = l(:notice_failed_to_update)
        else
          @issues.each do |issue|
            unless params[:preserve_parent_precedence]
              issue.blocks(issue.parent).destroy if issue.blocks?(issue.parent)
            end
            if i.nil?
              issue.move_to_root()
            else
              issue.move_to_child_of(i) 
              issue.blocks(i)
            end
          end
          flash[:notice] = l(:notice_successful_update) unless @issues.empty?
        end
      end
      redirect_to(params[:back_to] || {:controller => 'issues', :action => 'index', :project_id => @project})
      return
    end
  end

  def copy_subissue
    @allowed_projects = []
    # find projects to which the user is allowed to move the issue
    if User.current.admin?
      # admin is allowed to move issues to any active (visible) project
      @allowed_projects = Project.find(:all, :conditions => Project.visible_by(User.current))
    else
      User.current.memberships.each {|m| @allowed_projects << m.project if (m.respond_to?(:roles) ? m.roles.detect {|r| r.allowed_to?(:edit_parent)} : m.role.allowed_to?(:edit_parent)) }
    end
    @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:new_project_id]} if params[:new_project_id]
    @target_project ||= @project
    @trackers = @target_project.trackers
    if request.post?
      p_issue = @issues.first
      new_tracker = params[:new_tracker_id].blank? ? p_issue.tracker : @target_project.trackers.find_by_id(params[:new_tracker_id])
      i2 = Issue.new
      i2.project = @target_project
      i2.created_on = Time.now
      i2.subject = params[:new_subject]
      i2.status_id = params[:new_status_id]
      i2.priority_id = params[:new_priority_id]
      i2.assigned_to_id = params[:new_assigned_to_id] if params[:new_assigned_to_id]
      i2.description = params[:new_description]
      i2.author = User.current
      i2.done_ratio = 0
      i2.tracker = new_tracker
      i2.blocks(i2.parent)
      if i2.save && i2.move_to_child_of(p_issue)
        flash[:notice] = l(:notice_successful_create)
      else
        flash[:error] = l(:notice_failed_to_create_subissue)
      end
      redirect_to :controller => 'issues', :action => 'show', :id => @issues[0].id
      return
    end
    render :layout => false if request.xhr?
  end

  private
  def find_all_issues
    @issues = Issue.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @issues.empty?
    projects = @issues.collect(&:project).compact.uniq
    @project = projects.first
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def retrieve_query_with_groupby
    retrieve_query_without_groupby
    if params[:query_id].blank?
      @query.group_by = params[:group_by] if params[:group_by]
    end
  end
  alias_method_chain :retrieve_query, :groupby
end

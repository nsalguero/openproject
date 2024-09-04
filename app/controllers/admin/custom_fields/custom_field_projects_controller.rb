# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Admin::CustomFields::CustomFieldProjectsController < ApplicationController
  include OpTurbo::ComponentStream
  include OpTurbo::DialogStreamHelper

  layout "admin"

  model_object CustomField

  before_action :require_admin
  before_action :find_model_object

  before_action :available_project_custom_fields_query, only: :index
  before_action :initialize_custom_field_project, only: :new
  before_action :find_projects_to_activate_for_custom_field, only: :create

  menu_item :custom_fields

  def index; end

  def new
    respond_with_dialog Admin::CustomFields::CustomFieldProjects::NewCustomFieldProjectsModalComponent.new(
      custom_field_project_mapping: @custom_field_project,
      custom_field: @custom_field
    )
  end

  def create
    create_service = ::CustomFields::CustomFieldProjects::BulkCreateService
                         .new(user: current_user, projects: @projects, custom_field: @custom_field,
                              include_sub_projects: include_sub_projects?)
                         .call

    create_service.on_success { render_project_list(url_for_action: :index) }

    create_service.on_failure do
      update_flash_message_via_turbo_stream(
        message: join_flash_messages(create_service.errors),
        full: true, dismiss_scheme: :hide, scheme: :danger
      )
    end

    respond_to_with_turbo_streams(status: create_service.success? ? :ok : :unprocessable_entity)
  end

  def default_breadcrumb; end

  def show_local_breadcrumb
    false
  end

  private

  def render_project_list(url_for_action: action_name)
    update_via_turbo_stream(
      component: Admin::CustomFields::CustomFieldProjects::TableComponent.new(
        query: available_project_custom_fields_query,
        params: { custom_field: @custom_field, url_for_action: }
      )
    )
  end

  def find_model_object(object_id = :custom_field_id)
    super
    @custom_field = @object
  end

  def find_projects_to_activate_for_custom_field
    if (project_ids = params.to_unsafe_h[:custom_fields_project][:project_ids]).present?
      @projects = Project.find(project_ids)
    else
      initialize_custom_field_project
      @custom_field_project.errors.add(:project_ids, :blank)
      update_via_turbo_stream(
        component: Admin::CustomFields::CustomFieldProjects::NewCustomFieldProjectsFormModalComponent.new(
          custom_field_project_mapping: @custom_field_project,
          custom_field: @custom_field
        ),
        status: :bad_request
      )
      respond_with_turbo_streams
    end
  rescue ActiveRecord::RecordNotFound
    update_flash_message_via_turbo_stream message: t(:notice_project_not_found), full: true, dismiss_scheme: :hide,
                                          scheme: :danger
    update_project_list_via_turbo_stream

    respond_with_turbo_streams
  end

  def update_project_list_via_turbo_stream(url_for_action: action_name)
    update_via_turbo_stream(
      component: Admin::CustomFields::CustomFieldProjects::TableComponent.new(
        query: available_project_custom_fields_query,
        params: { custom_field: @custom_field, url_for_action: }
      )
    )
  end

  def available_project_custom_fields_query
    @available_project_custom_fields_query = ProjectQuery.new(
      name: "custom-fields-projects-#{@custom_field.id}"
    ) do |query|
      query.where(:available_project_custom_fields, "=", [@custom_field.id])
      query.select(:name)
      query.order("lft" => "asc")
    end
  end

  def initialize_custom_field_project
    @custom_field_project = ::CustomFields::CustomFieldProjects::SetAttributesService
                        .new(user: current_user, model: CustomFieldsProject.new, contract_class: EmptyContract)
                        .call(custom_field: @custom_field)
                        .result
  end

  def include_sub_projects?
    ActiveRecord::Type::Boolean.new.cast(params.to_unsafe_h[:custom_fields_project][:include_sub_projects])
  end
end

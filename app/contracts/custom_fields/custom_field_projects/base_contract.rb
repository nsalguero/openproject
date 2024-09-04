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

module CustomFields
  module CustomFieldProjects
    class BaseContract < ::ModelContract
      attribute :project_id
      attribute :custom_field_id

      validate :select_custom_fields_permission
      validate :not_for_all
      # FIXME: Confirm whether visible context is relevant
      # validate :visible_to_user

      def select_custom_fields_permission
        return if user.allowed_in_project?(:select_custom_fields, model.project)

        errors.add :base, :error_unauthorized
      end

      def not_for_all
        # Only mappings of custom fields which are not enabled for all projects can be manipulated by the user
        return if model.custom_field.nil? || !model.custom_field.is_for_all?

        errors.add :custom_field_id, :cannot_delete_mapping
      end

      def visible_to_user
        # "invisible" custom fields can only be seen and edited by admins
        # using visible scope to check if the custom field is actually visible to the user
        return if model.custom_field.nil? ||
                  CustomField.visible(user).pluck(:id).include?(model.custom_field.id)

        errors.add :custom_field_id, :invalid
      end
    end
  end
end

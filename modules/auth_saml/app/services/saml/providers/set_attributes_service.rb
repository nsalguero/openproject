#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Saml
  module Providers
    class SetAttributesService < BaseServices::SetAttributes
      private

      def set_attributes(params)
        update_mapping(params)

        super
      end

      def set_default_attributes(*)
        model.change_by_system do
          set_default_creator
          set_default_mapping
          set_issuer
          set_name_identifier_format
        end
      end

      def set_name_identifier_format
        model.name_identifier_format ||= Saml::Defaults::NAME_IDENTIFIER_FORMAT
      end

      def set_default_creator
        model.creator = user
      end

      ##
      # Clean up provided mapping, reducing whitespace
      def update_mapping(params)
        %i[mapping_mail mapping_login mapping_firstname mapping_lastname].each do |attr|
          next unless params.key?(attr)

          mapping = params.delete(attr)
          mapping.gsub!("\r\n", "\n")
          mapping.gsub!(/^\s*(.+?)\s*$/, '\1')

          model.public_send(:"#{attr}=", mapping)
        end
      end

      def set_default_mapping
        model.mapping_login ||= Saml::Defaults::MAIL_MAPPING
        model.mapping_mail ||= Saml::Defaults::MAIL_MAPPING
        model.mapping_firstname ||= Saml::Defaults::FIRSTNAME_MAPPING
        model.mapping_lastname ||= Saml::Defaults::LASTNAME_MAPPING
        model.request_attributes ||= Saml::Defaults::REQUESTED_ATTRIBUTES
      end

      def set_issuer
        model.sp_entity_id ||= OpenProject::StaticRouting::StaticUrlHelpers.new.root_url
      end
    end
  end
end

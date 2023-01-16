# Redmine Import Xml - A Redmine Plugin
# Copyright (C) 2023  Frederico Camara
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

module RedmineImportXml
  module Patches
    module ImportsControllerPatch

      def settings
        unless @import.file_exists?
          super
        else
          doc = File.open(@import.filepath) { |f| Nokogiri::XML(f) }
          if doc.errors.any?
            super
          else
            doc = Hash.from_xml(doc.to_s)["issue"]
            # File is valid XML try to import
            @issue = Issue.new(
              id: doc["id"],
              tracker_id:       doc.dig("tracker", "id"),
              project_id:       doc.dig("project", "id"),
              subject:          doc["subject"],
              description:      doc["description"],
              due_date:         doc["due_date"],
              category_id:      doc.dig("category", "id"),
              status_id:        doc.dig("status", "id"),
              assigned_to_id:   doc.dig("assigned_to", "id"),
              priority_id:      doc.dig("priority", "id"),
              fixed_version_id: doc.dig("fixed_version", "id"),
              author_id:        doc.dig("author", "id"),
              updated_on:       doc["updated_on"],
              start_date:       doc["start_date"],
              done_ratio:       doc["done_ratio"],
              estimated_hours:  doc["estimated_hours"],
              parent_id:        doc.dig("parent", "id"),
              is_private:       doc["is_private"],
              closed_on:        doc["closed_on"]
            )

            @issue.custom_field_values = doc["custom_fields"].map{|c| [c["id"], c["value"]]}.to_h

            doc["journals"].each do |j|
              @issue.journals.new(
                user_id: j.dig("user", "id"),
                notes: j["notes"],
                created_on: j["created_on"],
                private_notes: j["private_notes"]
              )
              j["details"].each do |d|
                @issue.journals.last.details.new(
                  property: d["property"],
                  prop_key: d["name"],
                  old_value: d["old_value"],
                  value: d["new_value"]
                )
              end
            end

            validation_errors = []
            validation_errors += [ l(:error_issue_already_exists, :id => @issue.id) ]         if Issue.where(id: @issue.id).any?
            validation_errors += [ l(:error_attribute_does_not_exist, :attr => l(:field_tracker)) ]       unless @issue.tracker.present?
            validation_errors += [ l(:error_attribute_does_not_exist, :attr => l(:field_project)) ]       unless @issue.project.present?
            validation_errors += [ l(:error_attribute_does_not_exist, :attr => l(:field_category)) ]      unless @issue.category.present?      if doc.dig("category", "id").present?
            validation_errors += [ l(:error_attribute_does_not_exist, :attr => l(:field_status)) ]        unless @issue.status.present?
            validation_errors += [ l(:error_attribute_does_not_exist, :attr => l(:field_assigned_to)) ]   unless @issue.assigned_to.present?   if doc.dig("assigned_to", "id").present?
            validation_errors += [ l(:error_attribute_does_not_exist, :attr => l(:field_fixed_version)) ] unless @issue.fixed_version.present? if doc.dig("fixed_version", "id").present?
            validation_errors += [ l(:error_attribute_does_not_exist, :attr => l(:field_author)) ]        unless @issue.author.present?
            validation_errors += [ l(:error_attribute_does_not_exist, :attr => l(:field_parent_issue)) ]  unless @issue.parent.present?        if doc.dig("parent", "id").present?

            if validation_errors.any?
              flash.now[:error] = validation_errors.join("; ")
              render :action => 'new'
            else
              if @issue.save && @issue.update(created_on: doc["created_on"])
                flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("##{@issue.id}", issue_path(@issue), :title => @issue.subject))
                render :action => 'new'
              else
                flash.now[:error] = @issue.errors.full_messages.join("; ")
                render :action => 'new'
              end
            end
          end
        end
      end

    end
  end
end

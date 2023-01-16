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

Redmine::Plugin.register :redmine_import_xml do
  name 'Redmine Import Xml plugin'
  author 'Frederico Camara'
  description 'This plugin imports back a single issue xml file (exported with REST GET /issues/[id].xml)'
  version '0.1'
  url 'http://github.com/fredsdc/redmine_import_xml'
  author_url 'http://github.com/fredsdc'
end

Rails.configuration.to_prepare do
  ImportsController.prepend(RedmineImportXml::Patches::ImportsControllerPatch)
end

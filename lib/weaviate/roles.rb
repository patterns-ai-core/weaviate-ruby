# frozen_string_literal: true

module Weaviate
  # Manage RBAC roles and their permissions. Requires RBAC to be enabled.
  class Roles < Base
    PATH = "authz/roles"

    def list
      response = client.connection.get(PATH)
      response.body
    end

    def get(name:)
      response = client.connection.get("#{PATH}/#{name}")
      response.body
    end

    # @param permissions [Array<Hash>] e.g. [{ action: "read_data", data: { collection: "Products" } }]
    def create(name:, permissions:)
      response = client.connection.post(PATH) do |req|
        req.body = {name: name, permissions: permissions}
      end
      response.success?
    end

    def delete(name:)
      response = client.connection.delete("#{PATH}/#{name}")
      response.success?
    end

    def add_permissions(name:, permissions:)
      response = client.connection.post("#{PATH}/#{name}/add-permissions") do |req|
        req.body = {permissions: permissions}
      end
      response.success?
    end

    def remove_permissions(name:, permissions:)
      response = client.connection.post("#{PATH}/#{name}/remove-permissions") do |req|
        req.body = {permissions: permissions}
      end
      response.success?
    end

    # @param permission [Hash] e.g. { action: "read_data", data: { collection: "Products" } }
    def has_permission?(name:, permission:)
      response = client.connection.post("#{PATH}/#{name}/has-permission") do |req|
        req.body = permission
      end
      response.body == true
    end

    # Users the role is assigned to.
    def user_assignments(name:)
      response = client.connection.get("#{PATH}/#{name}/user-assignments")
      response.body
    end

    # Groups the role is assigned to.
    def group_assignments(name:)
      response = client.connection.get("#{PATH}/#{name}/group-assignments")
      response.body
    end
  end
end

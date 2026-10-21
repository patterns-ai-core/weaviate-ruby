# frozen_string_literal: true

module Weaviate
  # Manage database users and their roles. Requires RBAC to be enabled.
  class Users < Base
    PATH = "users"
    USER_TYPES = %w[db oidc].freeze

    # Information about the current user.
    def own_info
      response = client.connection.get("#{PATH}/own-info")
      response.body
    end

    def list(include_last_used_time: nil)
      response = client.connection.get("#{PATH}/db") do |req|
        req.params["includeLastUsedTime"] = include_last_used_time unless include_last_used_time.nil?
      end
      response.body
    end

    def get(user_id:, include_last_used_time: nil)
      response = client.connection.get("#{PATH}/db/#{user_id}") do |req|
        req.params["includeLastUsedTime"] = include_last_used_time unless include_last_used_time.nil?
      end
      response.body
    end

    # Create a database user. The response contains the user's API key.
    def create(user_id:)
      response = client.connection.post("#{PATH}/db/#{user_id}")
      response.body
    end

    def delete(user_id:)
      response = client.connection.delete("#{PATH}/db/#{user_id}")
      response.success?
    end

    def activate(user_id:)
      response = client.connection.post("#{PATH}/db/#{user_id}/activate")
      response.success?
    end

    # @param revoke_key [Boolean] Also revoke the user's API key
    def deactivate(user_id:, revoke_key: nil)
      response = client.connection.post("#{PATH}/db/#{user_id}/deactivate") do |req|
        req.body = {revoke_key: revoke_key} unless revoke_key.nil?
      end
      response.success?
    end

    # Rotate a user's API key. The response contains the new key.
    def rotate_key(user_id:)
      response = client.connection.post("#{PATH}/db/#{user_id}/rotate-key")
      response.body
    end

    # @param user_type [String] "db" or "oidc"
    def roles(user_id:, user_type: "db", include_full_roles: nil)
      validate_user_type!(user_type)

      response = client.connection.get("authz/users/#{user_id}/roles/#{user_type}") do |req|
        req.params["includeFullRoles"] = include_full_roles unless include_full_roles.nil?
      end
      response.body
    end

    def assign_roles(user_id:, roles:, user_type: "db")
      update_roles(user_id, "assign", roles, user_type)
    end

    def revoke_roles(user_id:, roles:, user_type: "db")
      update_roles(user_id, "revoke", roles, user_type)
    end

    private

    def update_roles(user_id, action, roles, user_type)
      validate_user_type!(user_type)

      response = client.connection.post("authz/users/#{user_id}/#{action}") do |req|
        req.body = {roles: Array(roles), userType: user_type}
      end
      response.success?
    end

    def validate_user_type!(user_type)
      unless USER_TYPES.include?(user_type.to_s)
        raise ArgumentError, 'user_type must be either "db" or "oidc"'
      end
    end
  end
end

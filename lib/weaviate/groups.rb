# frozen_string_literal: true

module Weaviate
  # Manage roles of OIDC groups. Requires RBAC and OIDC to be enabled.
  class Groups < Base
    PATH = "authz/groups"
    GROUP_TYPE = "oidc"

    # Groups that have roles assigned.
    def list
      response = client.connection.get("#{PATH}/#{GROUP_TYPE}")
      response.body
    end

    def roles(group_id:, include_full_roles: nil)
      response = client.connection.get("#{PATH}/#{group_id}/roles/#{GROUP_TYPE}") do |req|
        req.params["includeFullRoles"] = include_full_roles unless include_full_roles.nil?
      end
      response.body
    end

    def assign_roles(group_id:, roles:)
      update_roles(group_id, "assign", roles)
    end

    def revoke_roles(group_id:, roles:)
      update_roles(group_id, "revoke", roles)
    end

    private

    def update_roles(group_id, action, roles)
      response = client.connection.post("#{PATH}/#{group_id}/#{action}") do |req|
        req.body = {roles: Array(roles), groupType: GROUP_TYPE}
      end
      response.success?
    end
  end
end

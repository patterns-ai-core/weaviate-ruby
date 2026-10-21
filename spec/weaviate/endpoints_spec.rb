# frozen_string_literal: true

require "spec_helper"

# Request-level specs for endpoints added for parity with the Weaviate 1.38 REST API
RSpec.describe "Weaviate endpoints" do
  let(:client) { Weaviate::Client.new(url: "http://localhost:8080", logger: Logger.new(nil)) }

  describe Weaviate::Objects do
    let!(:requests) { stub_weaviate }
    let(:objects) { client.objects }

    it "adds a reference" do
      expect(objects.add_reference(class_name: "Post", id: "p1", property: "ofCategory", to_class_name: "Category", to_id: "c1", tenant: "a")).to eq(true)
      expect(request_summary(requests.last)).to eq(
        ["POST", "/v1/objects/Post/p1/references/ofCategory?tenant=a", {"beacon" => "weaviate://localhost/Category/c1"}]
      )
    end

    it "replaces references" do
      objects.replace_references(class_name: "Post", id: "p1", property: "ofCategory", to: [{class_name: "Category", id: "c1"}, {class_name: "Category", id: "c2"}])
      expect(request_summary(requests.last)).to eq(
        ["PUT", "/v1/objects/Post/p1/references/ofCategory", [{"beacon" => "weaviate://localhost/Category/c1"}, {"beacon" => "weaviate://localhost/Category/c2"}]]
      )
    end

    it "deletes a reference" do
      objects.delete_reference(class_name: "Post", id: "p1", property: "ofCategory", to_class_name: "Category", to_id: "c1", consistency_level: "quorum")
      expect(request_summary(requests.last)).to eq(
        ["DELETE", "/v1/objects/Post/p1/references/ofCategory?consistency_level=QUORUM", {"beacon" => "weaviate://localhost/Category/c1"}]
      )
    end

    it "batch creates references" do
      objects.batch_create_references(references: [
        {from_class_name: "Post", from_id: "p1", property: "ofCategory", to_class_name: "Category", to_id: "c1"},
        {from_class_name: "Post", from_id: "p2", property: "ofCategory", to_class_name: "Category", to_id: "c1", tenant: "a"}
      ])
      expect(request_summary(requests.last)).to eq(
        ["POST", "/v1/batch/references", [
          {"from" => "weaviate://localhost/Post/p1/ofCategory", "to" => "weaviate://localhost/Category/c1"},
          {"from" => "weaviate://localhost/Post/p2/ofCategory", "to" => "weaviate://localhost/Category/c1", "tenant" => "a"}
        ]]
      )
    end
  end

  describe Weaviate::Collections do
    let(:collections) { client.collections }

    it "updates tenants" do
      requests = stub_weaviate(body: "[]")
      collections.update_tenants(class_name: "Question", tenants: [{name: "a", activityStatus: "COLD"}])
      expect(request_summary(requests.last)).to eq(["PUT", "/v1/schema/Question/tenants", [{"name" => "a", "activityStatus" => "COLD"}]])
    end

    it "gets a tenant" do
      requests = stub_weaviate(body: '{"name": "a", "activityStatus": "HOT"}')
      expect(collections.get_tenant(class_name: "Question", tenant: "a")).to eq("name" => "a", "activityStatus" => "HOT")
      expect(request_summary(requests.last)).to eq(["GET", "/v1/schema/Question/tenants/a", nil])
    end

    it "checks if a tenant exists" do
      stub_weaviate(body: "")
      expect(collections.tenant_exists?(class_name: "Question", tenant: "a")).to eq(true)

      stub_weaviate(status: 404, body: "")
      expect(collections.tenant_exists?(class_name: "Question", tenant: "missing")).to eq(false)
    end

    it "filters shards by tenant" do
      requests = stub_weaviate(body: "[]")
      collections.shards(class_name: "Question", tenant: "a")
      expect(request_summary(requests.last)).to eq(["GET", "/v1/schema/Question/shards?tenant=a", nil])
    end
  end

  describe Weaviate::Backups do
    let!(:requests) { stub_weaviate(body: "[]") }
    let(:backups) { client.backups }

    it "lists backups" do
      backups.list(backend: "s3", order: "asc")
      expect(request_summary(requests.last)).to eq(["GET", "/v1/backups/s3?order=asc", nil])
    end

    it "passes config when creating and restoring" do
      backups.create(backend: "s3", id: "b1", config: {Bucket: "my-bucket", Path: "backups"})
      expect(request_summary(requests.last)).to eq(["POST", "/v1/backups/s3", {"id" => "b1", "config" => {"Bucket" => "my-bucket", "Path" => "backups"}}])

      backups.restore(backend: "s3", id: "b1", config: {Bucket: "my-bucket"})
      expect(request_summary(requests.last)).to eq(["POST", "/v1/backups/s3/b1/restore", {"config" => {"Bucket" => "my-bucket"}}])
    end

    it "passes bucket and path when reading status" do
      backups.get(backend: "s3", id: "b1", bucket: "my-bucket", path: "backups")
      expect(request_summary(requests.last)).to eq(["GET", "/v1/backups/s3/b1?bucket=my-bucket&path=backups", nil])

      backups.restore_status(backend: "s3", id: "b1", bucket: "my-bucket")
      expect(request_summary(requests.last)).to eq(["GET", "/v1/backups/s3/b1/restore?bucket=my-bucket", nil])
    end

    it "cancels backups and restores" do
      expect(backups.cancel(backend: "s3", id: "b1")).to eq(true)
      expect(request_summary(requests.last)).to eq(["DELETE", "/v1/backups/s3/b1", nil])

      expect(backups.cancel_restore(backend: "s3", id: "b1")).to eq(true)
      expect(request_summary(requests.last)).to eq(["DELETE", "/v1/backups/s3/b1/restore", nil])
    end
  end

  describe Weaviate::Nodes do
    let!(:requests) { stub_weaviate(body: '{"nodes": []}') }

    it "lists nodes" do
      client.nodes
      expect(request_summary(requests.last)).to eq(["GET", "/v1/nodes", nil])
    end

    it "passes output, collection and shard" do
      client.nodes(output: "verbose", class_name: "Question", shard_name: "abc")
      expect(request_summary(requests.last)).to eq(["GET", "/v1/nodes/Question?output=verbose&shardName=abc", nil])
    end
  end

  describe Weaviate::Aliases do
    let!(:requests) { stub_weaviate }
    let(:aliases) { client.aliases }

    it "manages aliases" do
      aliases.list(class_name: "Question")
      expect(request_summary(requests.last)).to eq(["GET", "/v1/aliases?class=Question", nil])

      aliases.create(alias_name: "Q", class_name: "Question")
      expect(request_summary(requests.last)).to eq(["POST", "/v1/aliases", {"alias" => "Q", "class" => "Question"}])

      aliases.get(alias_name: "Q")
      expect(request_summary(requests.last)).to eq(["GET", "/v1/aliases/Q", nil])

      aliases.update(alias_name: "Q", class_name: "QuestionV2")
      expect(request_summary(requests.last)).to eq(["PUT", "/v1/aliases/Q", {"class" => "QuestionV2"}])

      expect(aliases.delete(alias_name: "Q")).to eq(true)
      expect(request_summary(requests.last)).to eq(["DELETE", "/v1/aliases/Q", nil])
    end
  end

  describe Weaviate::Users do
    let!(:requests) { stub_weaviate }
    let(:users) { client.users }

    it "manages database users" do
      users.own_info
      users.list(include_last_used_time: true)
      users.get(user_id: "bob")
      users.create(user_id: "bob")
      users.activate(user_id: "bob")
      users.deactivate(user_id: "bob", revoke_key: true)
      users.rotate_key(user_id: "bob")
      users.delete(user_id: "bob")

      expect(requests.map { |r| request_summary(r) }).to eq([
        ["GET", "/v1/users/own-info", nil],
        ["GET", "/v1/users/db?includeLastUsedTime=true", nil],
        ["GET", "/v1/users/db/bob", nil],
        ["POST", "/v1/users/db/bob", nil],
        ["POST", "/v1/users/db/bob/activate", nil],
        ["POST", "/v1/users/db/bob/deactivate", {"revoke_key" => true}],
        ["POST", "/v1/users/db/bob/rotate-key", nil],
        ["DELETE", "/v1/users/db/bob", nil]
      ])
    end

    it "manages user roles" do
      users.roles(user_id: "bob", include_full_roles: true)
      users.assign_roles(user_id: "bob", roles: ["reader"])
      users.revoke_roles(user_id: "alice", roles: "reader", user_type: "oidc")

      expect(requests.map { |r| request_summary(r) }).to eq([
        ["GET", "/v1/authz/users/bob/roles/db?includeFullRoles=true", nil],
        ["POST", "/v1/authz/users/bob/assign", {"roles" => ["reader"], "userType" => "db"}],
        ["POST", "/v1/authz/users/alice/revoke", {"roles" => ["reader"], "userType" => "oidc"}]
      ])
    end

    it "validates the user type" do
      expect { users.roles(user_id: "bob", user_type: "ldap") }.to raise_error(ArgumentError)
    end
  end

  describe Weaviate::Roles do
    let(:roles) { client.roles }
    let(:permission) { {action: "read_data", data: {collection: "Question"}} }

    it "manages roles" do
      requests = stub_weaviate
      roles.list
      roles.get(name: "reader")
      roles.create(name: "reader", permissions: [permission])
      roles.add_permissions(name: "reader", permissions: [permission])
      roles.remove_permissions(name: "reader", permissions: [permission])
      roles.user_assignments(name: "reader")
      roles.group_assignments(name: "reader")
      roles.delete(name: "reader")

      json_permission = {"action" => "read_data", "data" => {"collection" => "Question"}}
      expect(requests.map { |r| request_summary(r) }).to eq([
        ["GET", "/v1/authz/roles", nil],
        ["GET", "/v1/authz/roles/reader", nil],
        ["POST", "/v1/authz/roles", {"name" => "reader", "permissions" => [json_permission]}],
        ["POST", "/v1/authz/roles/reader/add-permissions", {"permissions" => [json_permission]}],
        ["POST", "/v1/authz/roles/reader/remove-permissions", {"permissions" => [json_permission]}],
        ["GET", "/v1/authz/roles/reader/user-assignments", nil],
        ["GET", "/v1/authz/roles/reader/group-assignments", nil],
        ["DELETE", "/v1/authz/roles/reader", nil]
      ])
    end

    it "checks a permission" do
      requests = stub_weaviate(body: "true")
      expect(roles.has_permission?(name: "reader", permission: permission)).to eq(true)
      expect(request_summary(requests.last)).to eq(["POST", "/v1/authz/roles/reader/has-permission", {"action" => "read_data", "data" => {"collection" => "Question"}}])

      stub_weaviate(body: "false")
      expect(roles.has_permission?(name: "reader", permission: permission)).to eq(false)
    end
  end

  describe Weaviate::Groups do
    let!(:requests) { stub_weaviate }

    it "manages OIDC group roles" do
      client.groups.list
      client.groups.roles(group_id: "admins")
      client.groups.assign_roles(group_id: "admins", roles: ["admin"])
      client.groups.revoke_roles(group_id: "admins", roles: ["admin"])

      expect(requests.map { |r| request_summary(r) }).to eq([
        ["GET", "/v1/authz/groups/oidc", nil],
        ["GET", "/v1/authz/groups/admins/roles/oidc", nil],
        ["POST", "/v1/authz/groups/admins/assign", {"roles" => ["admin"], "groupType" => "oidc"}],
        ["POST", "/v1/authz/groups/admins/revoke", {"roles" => ["admin"], "groupType" => "oidc"}]
      ])
    end
  end
end

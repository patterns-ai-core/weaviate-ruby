# frozen_string_literal: true

require "spec_helper"

RSpec.describe Weaviate::Backups do
  let(:client) {
    Weaviate::Client.new(
      url: "http://localhost:8080"
    )
  }

  let(:backups) { client.backups }
  let(:backup_fixture) { JSON.parse(File.read("spec/fixtures/backup.json")) }

  describe "#create" do
    let(:response) { OpenStruct.new(success?: true, body: backup_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with("backups/filesystem")
        .and_return(response)
    end

    it "creates the backup" do
      response = backups.create(
        backend: "filesystem",
        id: "my-first-backup",
        include: ["Question"]
      )
      expect(response["id"]).to eq("my-first-backup")
      expect(response["status"]).to eq("STARTED")
    end
  end

  describe "#get" do
    let(:response) { OpenStruct.new(success?: true, body: backup_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("backups/filesystem/my-first-backup")
        .and_return(response)
    end

    it "returns the backup" do
      response = backups.get(
        backend: "filesystem",
        id: "my-first-backup"
      )
      expect(response["id"]).to eq("my-first-backup")
    end
  end

  describe "#restore" do
    let(:response) { OpenStruct.new(success?: true, body: backup_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with("backups/filesystem/my-first-backup/restore")
        .and_return(response)
    end

    it "restores the backup" do
      response = backups.restore(
        backend: "filesystem",
        id: "my-first-backup",
        include: ["Question"]
      )
      expect(response["id"]).to eq("my-first-backup")
      expect(response["status"]).to eq("STARTED")
    end
  end

  describe "#restore_status" do
    let(:response) { OpenStruct.new(success?: true, body: backup_fixture) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with("backups/filesystem/my-first-backup/restore")
        .and_return(response)
    end

    it "returns the restore status" do
      response = backups.restore_status(
        backend: "filesystem",
        id: "my-first-backup"
      )
      expect(response["id"]).to eq("my-first-backup")
    end
  end
end

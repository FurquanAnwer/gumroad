# frozen_string_literal: true

require "spec_helper"

RSpec.describe VideoFile, type: :model do
  it "schedules a job to analyze the file after creation" do
    video_file = create(:video_file)

    expect(AnalyzeFileWorker).to have_enqueued_sidekiq_job(video_file.id, VideoFile.name)
  end

  describe "#url" do
    it "must startwith S3_BASE_URL" do
      video_file = build(:video_file)

      video_file.url = "#{S3_BASE_URL}/video.mp4"
      video_file.validate
      expect(video_file.errors[:url]).to be_empty

      video_file.url = "https://example.com/video.mp4"
      video_file.validate
      expect(video_file.errors[:url]).to include("must be an S3 URL")
    end
  end

  describe "#smil_xml" do
    it "returns properly formatted SMIL XML with signed cloudfront URL" do
      s3_key = "attachments/1234567890abcdef1234567890abcdef/original/myvideo.mp4"
      s3_url = "#{S3_BASE_URL}attachments/1234567890abcdef1234567890abcdef/original/myvideo.mp4"
      signed_url = "https://cdn.example.com/signed-url-for-video.mp4"

      video_file = create(:video_file, url: s3_url)

      allow(video_file).to receive(:signed_cloudfront_url).with(s3_key, is_video: true).and_return(signed_url)

      expected_xml = <<~XML.strip
        <smil><body><switch><video src="#{signed_url}"/></switch></body></smil>
      XML
      expect(video_file.smil_xml).to eq(expected_xml)
    end
  end
end

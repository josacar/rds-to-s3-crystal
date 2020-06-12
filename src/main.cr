require "aws-credentials"
require "db"
require "crambda"
require "csv"
require "mysql"
require "awscr-s3"

def handler(event : JSON::Any, context : Crambda::Context)
  begin
    pp context

    host = ENV.fetch("RDS_HOST")
    user = ENV.fetch("RDS_USER")
    password = ENV.fetch("RDS_PASSWORD")
    port = ENV.fetch("RDS_PORT")
    database = ENV.fetch("RDS_DATABASE")
    bucket_name = ENV.fetch("S3_BUCKET_NAME")
    bucket_path = "#{ENV.fetch("S3_BUCKET_PATH_PREFIX")}-#{Time.utc.to_s("%Y%m%d")}.csv"
    bucket_region = ENV.fetch("S3_BUCKET_REGION")

    client = DB.open("mysql://#{user}:#{password}@#{host}/#{database}")

    query = %q{SELECT
      wadus_id as ref,
      DATE_FORMAT(now(), "%Y-%m-%e %k:%i:%s") as "date"
      from
      wadus_metadata
      where
      JSON_CONTAINS_PATH(metadata, "one", "$.ownerId");
    }

    results = client.query(query)

    provider = Aws::Credentials::Providers.new([
      Aws::Credentials::EnvProvider.new,
      Aws::Credentials::InstanceMetadataProvider.new,
      Aws::Credentials::ContainerCredentialProvider.new
    ] of Aws::Credentials::Provider)

    content = CSV.build do |csv|
      results.each do
        csv.row(results.read(String),results.read(String))
      end
    end

    puts content

    s3_client = Awscr::S3::Client.new(bucket_region, provider.credentials.access_key_id, provider.credentials.secret_access_key)
    # s3_client.put_object(bucket_name, bucket_path, content) # FIXME SSL cert error
  ensure
    client.close if client
  end

  {
    "test" => "wadus"
  }
end

Crambda.run_handler(->handler(JSON::Any, Crambda::Context))

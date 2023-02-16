require 'singleton'

class AwsClient
    include Singleton
    BUCKET='askmybook'
    REGION='us-east-1'

    private
    Aws.config.update(
            region: REGION,
            credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_ACCESS_KEY'])
        )
    @s3_client = Aws::S3::Client.new(region: REGION)

    def self.download_object(filename, objKey)
        @s3_client.get_object(
            response_target: filename,
            bucket: BUCKET,
            key: objKey
        )
    end
end

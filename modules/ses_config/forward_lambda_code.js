const AWS = require('aws-sdk');
const S3 = new AWS.S3({ region: 'us-east-1' });
const SES = new AWS.SES({ region: 'us-east-1' });

const FORWARD_TO = "sreekanthpaleti1999@gmail.com";
const SENDER_EMAIL = "support@sree84s.site";

exports.handler = async (event, context) => {
    try {
        const mail = event.Records[0].ses.mail;
        const s3Bucket = "sree84s-ses-inbound-mail-storage-0102";
        const s3Key = mail.messageId;

        console.log(`INFO Email received. S3 Bucket: ${s3Bucket}, Key: ${s3Key}, MessageId: ${mail.messageId}`);
        
        // Read the raw email data from S3
        const data = await S3.getObject({
            Bucket: s3Bucket,
            Key: s3Key
        }).promise();

        // Prepare email content for forwarding
        const emailContent = data.Body.toString();

        // Parameters for sending the raw email via SES
        const params = {
            Destinations: [FORWARD_TO],
            Source: SENDER_EMAIL,
            RawMessage: {
                Data: emailContent
            }
        };

        // Send the email (forwarding)
        await SES.sendRawEmail(params).promise();
        
        console.log(`SUCCESS Email forwarded successfully to ${FORWARD_TO}`);

        // Delete the email from S3 (optional, but good practice)
        await S3.deleteObject({
            Bucket: s3Bucket,
            Key: s3Key
        }).promise();
        
        console.log(`INFO S3 object ${s3Key} deleted.`);

        return { statusCode: 200, body: `Email forwarded to ${FORWARD_TO}` };

    } catch (error) {
        console.error("ERROR during email forwarding:", error);
        return { statusCode: 500, body: `Error processing email: ${error.message}` };
    }
};
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
        
        const data = await S3.getObject({
            Bucket: s3Bucket,
            Key: s3Key
        }).promise();

        let emailContent = data.Body.toString();

        // 1. Remove problematic headers that cause SES rejection
        emailContent = emailContent.replace(/^Return-Path: (.*)/m, "");
        emailContent = emailContent.replace(/^Sender: (.*)/m, "");
        emailContent = emailContent.replace(/^Message-ID: (.*)/m, "");

        // 2. IMPORTANT: Rewrite 'From' header to your verified identity
        emailContent = emailContent.replace(/^From: (.*)/m, `From: ${SENDER_EMAIL}`);

        // 3. Add Reply-To so you can respond to the original sender
        if (!emailContent.match(/^Reply-To:/m)) {
            emailContent = emailContent.replace(/^Subject: (.*)/m, `Subject: $1\nReply-To: ${mail.commonHeaders.from[0]}`);
        }

        const params = {
            Destinations: [FORWARD_TO],
            Source: SENDER_EMAIL, 
            RawMessage: {
                Data: emailContent
            }
        };

        await SES.sendRawEmail(params).promise();
        console.log(`SUCCESS Email forwarded successfully to ${FORWARD_TO}`);

        return { statusCode: 200, body: `Email forwarded to ${FORWARD_TO}` };

    } catch (error) {
        console.error("ERROR during email forwarding:", error);
        return { statusCode: 500, body: `Error processing email: ${error.message}` };
    }
};
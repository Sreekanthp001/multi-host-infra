const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const SES = new AWS.SES();

exports.handler = async (event) => {
    const mail = event.Records[0].ses.mail;
    const s3Bucket = process.env.S3_BUCKET;
    const s3Key = mail.messageId;
    const FORWARD_TO = process.env.FORWARD_TO;
    const SENDER_EMAIL = process.env.SENDER_EMAIL;

    try {
        const data = await S3.getObject({ Bucket: s3Bucket, Key: s3Key }).promise();
        const emailContent = data.Body.toString();

        await SES.sendRawEmail({
            Destinations: [FORWARD_TO],
            Source: SENDER_EMAIL,
            RawMessage: { Data: emailContent }
        }).promise();

        console.log(`Successfully forwarded email ${mail.messageId}`);
        return { statusCode: 200 };
    } catch (err) {
        console.error(err);
        throw err;
    }
};
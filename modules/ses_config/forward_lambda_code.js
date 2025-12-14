'use strict';

const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const SES = new AWS.SES();

const FORWARDING_EMAIL = "sreekanthpaleti1999@gmail.com"; 

exports.handler = async (event) => {
    console.log("SNS Event received:", JSON.stringify(event));

    const message = JSON.parse(event.Records[0].Sns.Message);
    const mail = message.mail;
    
    // Check for S3 object details safely
    const s3Object = message.receipt && message.receipt.action && message.receipt.action.object;

    if (!s3Object || s3Object.key.startsWith('AMAZON_SES_SETUP_NOTIFICATION')) {
        console.log("Skipping setup notification or missing S3 object details.");
        return;
    }

    try {
        // 1. Get email file from S3
        const data = await S3.getObject({
            Bucket: s3Object.bucketName,
            Key: s3Object.key
        }).promise();

        const email = data.Body.toString();
        console.log("Email content loaded from S3.");

        // 2. Forward email using SES
        const sendParams = {
            RawMessage: {
                Data: email 
            },
            Destinations: [FORWARDING_EMAIL],
            Source: FORWARDING_EMAIL, 
        };

        await SES.sendRawEmail(sendParams).promise();
        console.log(`Successfully forwarded email to: ${FORWARDING_EMAIL}`);

        // 3. Delete email file from S3 
        await S3.deleteObject({
            Bucket: s3Object.bucketName,
            Key: s3Object.key
        }).promise();
        console.log(`Successfully deleted email from S3: ${s3Object.key}`);

    } catch (error) {
        console.error("Error processing email:", error);
        throw error;
    }
};
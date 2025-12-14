'use strict';

const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const SES = new AWS.SES();

const FORWARDING_EMAIL = "sreekanthpaleti1999@gmail.com"; 

exports.handler = async (event) => {
    console.log("SNS Event received:", JSON.stringify(event));

    const message = JSON.parse(event.Records[0].Sns.Message);
    const mail = message.mail;
    
    // S3 ఆబ్జెక్ట్ వివరాలను సురక్షితంగా పొందండి
    const s3Object = message.receipt && message.receipt.action && message.receipt.action.object;

    // S3 ఆబ్జెక్ట్ డీటెయిల్స్ లేకపోతేనే ఆపివేయాలి (AMAZON_SES_SETUP_NOTIFICATION చెక్ తొలగించబడింది)
    if (!s3Object) { 
        console.log("Error: S3 object details are missing in the SNS notification. Skipping processing.");
        return;
    }

    try {
        // 1. S3 నుండి ఇమెయిల్ ఫైల్‌ను పొందండి
        const data = await S3.getObject({
            Bucket: s3Object.bucketName,
            Key: s3Object.key
        }).promise();

        const email = data.Body.toString();
        console.log("Email content loaded from S3.");

        // 2. SES ద్వారా ఇమెయిల్ ను ఫార్వార్డ్ చేయండి
        const sendParams = {
            RawMessage: {
                Data: email 
            },
            Destinations: [FORWARDING_EMAIL],
            Source: FORWARDING_EMAIL, 
        };

        await SES.sendRawEmail(sendParams).promise();
        console.log(`Successfully forwarded email to: ${FORWARDING_EMAIL}`);

        // 3. S3 నుండి ఇమెయిల్ ఫైల్‌ను తొలగించండి 
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
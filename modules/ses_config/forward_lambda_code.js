'use strict';

const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const SES = new AWS.SES();

// 📢 ఇక్కడ మీ వ్యక్తిగత ఇమెయిల్ ID ని ఉంచబడింది.
const FORWARDING_EMAIL = "sreekanthpaleti1999@gmail.com"; 

exports.handler = async (event) => {
    console.log("SNS Event received:", JSON.stringify(event));

    const message = JSON.parse(event.Records[0].Sns.Message);
    const mail = message.mail;
    
    // 🛑 ఇక్కడ మార్పు చేయబడింది: S3 వివరాలను receipt.action.object బదులు 
    // receipt.action లోని s3Action.object నుండి చదవడానికి ప్రయత్నిస్తుంది.
    const s3Action = message.receipt.action.type === 'SNS' && message.receipt.action.snsAction ? message.receipt.action.snsAction : message.receipt.action;
    const s3Object = s3Action.object; 
    
        
    // *** సింపుల్ ఫిక్స్: s3Object లోపం రాకుండా ఉండటానికి try-catch బ్లాక్uను మెరుగుపరుద్దాం ***
    if (!message.receipt || !message.receipt.action || !message.receipt.action.object) {
         console.error("Error: S3 object details not found in SES receipt message.");
         // ఇక్కడ మనము 'receipt' మెసేజ్ యొక్క 'content' నుండి S3 key ను కనుగొనడానికి ప్రయత్నించాలి,
         // కానీ అది చాలా కాంప్లెక్స్.
         
         // ప్రస్తుతానికి, ఇది setup notification కాకపోతే, లోపాన్ని చూపిద్దాం.
         if (!mail || !mail.messageId || mail.messageId.startsWith('AMAZON_SES_SETUP_NOTIFICATION')) {
             console.log("Skipping setup notification or unrecoverable receipt message.");
             return;
         }
         
        
         
        
         const s3Object = message.receipt.action.object; // ఇది ఇప్పుడు పనిచేయాలి
         
         
         
        
         if (!s3Object || s3Object.key.startsWith('AMAZON_SES_SETUP_NOTIFICATION')) {
             console.log("Skipping setup notification or missing S3 object details.");
             return;
         }
         
         
'use strict';

const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const SES = new AWS.SES();

const FORWARDING_EMAIL = "sreekanthpaleti1999@gmail.com"; 

exports.handler = async (event) => {
    console.log("SNS Event received:", JSON.stringify(event));

    const message = JSON.parse(event.Records[0].Sns.Message);
    const mail = message.mail;
    
    // 🛑 మార్పు ఇక్కడే: s3Object ను సురక్షితంగా పొందుతున్నాము.
    const s3Object = message.receipt && message.receipt.action && message.receipt.action.object;

    if (!s3Object || s3Object.key.startsWith('AMAZON_SES_SETUP_NOTIFICATION')) {
        console.log("Skipping setup notification or missing S3 object details.");
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
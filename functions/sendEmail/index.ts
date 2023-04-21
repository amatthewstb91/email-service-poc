import { cloudEvent } from "@google-cloud/functions-framework";

// Register a CloudEvent callback with the Functions Framework that will
// be executed when the Pub/Sub trigger topic receives a message.
interface EventData {
  message: {
    data: string
  }
}

cloudEvent('sendEmail', ev => {

  // The Pub/Sub message is passed as the CloudEvent's data payload.
  const base64name = (ev.data as EventData).message.data;

  const name = base64name
    ? Buffer.from(base64name, 'base64').toString()
    : 'World';

  console.log(`Hello, ${name}!`);
});

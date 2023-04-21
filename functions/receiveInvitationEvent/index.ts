import { http } from "@google-cloud/functions-framework";
import { PubSub } from "@google-cloud/pubsub";

const pubSub = new PubSub();

http('receiveInvitationEvent', async (req, res) => {
  const dataBuffer = Buffer.from(req.body);

  try {
    const messageId = await pubSub
      .topic('projects/matthew-law-dev/topics/invitations')
      .publishMessage({data: dataBuffer});

    console.log(`Message ${messageId} published.`);
    res.send(202);
  } catch (err) {

    console.error(`Received error while publishing: ${(err as TypeError).message}`);
    res.send(500);
  }

});

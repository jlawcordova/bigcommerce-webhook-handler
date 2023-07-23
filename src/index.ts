import { SQSHandler, SQSEvent } from "aws-lambda";
import { BigCommerceCallbackPayload } from "./bigcommerce";

export const handler: SQSHandler = (event: SQSEvent) => {
  event.Records.forEach((record) => {
    const callbackPayload: BigCommerceCallbackPayload = JSON.parse(record.body);

    // Create the processing logic for a BigCommerce callback payload here.
    console.log(JSON.stringify(callbackPayload));
  });

  return;
};

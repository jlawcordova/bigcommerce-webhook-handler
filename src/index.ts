import { SQSHandler, SQSEvent } from "aws-lambda";
import { BigCommerceCallbackPayload } from "./bigcommerce";
import { process } from "./process";

export const handler: SQSHandler = (event: SQSEvent) => {
  event.Records.forEach((record) => {
    const payload: BigCommerceCallbackPayload = JSON.parse(record.body);
    process(payload);
  });

  return;
};

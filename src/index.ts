interface Response {
  statusCode: Number;
  body: string;
}

export const handler = async (event) => {
  let response: Response = {
    statusCode: 200,
    body: JSON.stringify({}),
  };
  return response;
};

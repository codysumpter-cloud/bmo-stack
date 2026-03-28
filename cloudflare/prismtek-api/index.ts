export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/healthz") {
      return Response.json({ ok: true, service: "prismtek-api" });
    }
    return Response.json({ ok: true, service: "prismtek-api", path: url.pathname });
  },
};

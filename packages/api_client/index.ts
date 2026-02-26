export type ApiClientOptions = {
  baseUrl: string;
  headers?: Record<string, string>;
};

export class ApiClient {
  constructor(private readonly options: ApiClientOptions) {}

  async get<T>(path: string): Promise<T> {
    const res = await fetch(`${this.options.baseUrl}${path}`, {
      headers: this.options.headers,
      method: 'GET',
    });
    if (!res.ok) {
      throw new Error(`GET ${path} failed: ${res.status}`);
    }
    return (await res.json()) as T;
  }
}

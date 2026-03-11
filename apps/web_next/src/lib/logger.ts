type LogMeta = Record<string, unknown> | undefined;

function log(level: 'info' | 'warn' | 'error', message: string, meta?: LogMeta) {
  const payload = meta ? { message, ...meta } : { message };
  console[level](`[web_next] ${message}`, payload);
}

export const logger = {
  info(message: string, meta?: LogMeta) {
    log('info', message, meta);
  },
  warn(message: string, meta?: LogMeta) {
    log('warn', message, meta);
  },
  error(message: string, meta?: LogMeta) {
    log('error', message, meta);
  },
};

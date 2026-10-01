import { defineCollection } from 'astro:content';
import { docsLoader, i18nLoader } from '@astrojs/starlight/loaders';
import { docsSchema, i18nSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema(),
  }),
  // UI strings. Only the search label is set; everything
  // else falls back to Starlight's English defaults.
  i18n: defineCollection({ loader: i18nLoader(), schema: i18nSchema() }),
};

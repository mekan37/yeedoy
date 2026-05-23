import type { CSSProperties } from 'react';
import type { BrandTheme, BrandThemeDefinition } from '@/src/lib/brand-theme';
import { resolveAccentColor } from '@/src/lib/presentation-accent';
import type { ResolvedPresentationRecord } from '@/src/lib/presentation-settings';

export function getPresentationViewModel(
  presentation: ResolvedPresentationRecord,
  brandTheme: BrandTheme,
  template: BrandThemeDefinition,
) {
  const accentColor = resolveAccentColor({
    templateKey: brandTheme,
    settings: presentation.settings,
  });

  const pageStyle: CSSProperties = {
    backgroundImage: template.pageBackground,
    ['--menu-accent' as string]: accentColor,
  };

  const heroStyle: CSSProperties = {
    backgroundImage:
      presentation.settings.backgroundMode === 'gradient'
        ? template.heroBackground
        : presentation.settings.backgroundMode === 'solid'
          ? `linear-gradient(135deg, ${accentColor}, ${template.brandQrDark})`
          : template.heroBackground,
  };

  if (presentation.settings.backgroundMode === 'image' && presentation.backgroundUrl) {
    heroStyle.backgroundImage = `${template.heroBackground}, url(${presentation.backgroundUrl})`;
    heroStyle.backgroundSize = 'cover';
    heroStyle.backgroundPosition = 'center';
  }

  return {
    accentColor,
    template,
    pageStyle,
    heroStyle,
    fontScaleClassName:
      presentation.settings.fontScale === 'large' ? 'text-[1.04rem] sm:text-[1.06rem]' : '',
    denseCardClassName:
      presentation.settings.cardStyle === 'compact' ? 'p-3 sm:p-3.5' : 'p-4 sm:p-5',
    headerAlignClassName:
      presentation.settings.headerLayout === 'centered'
        ? 'text-center items-center'
        : 'text-left items-start',
    isDarkSurface: brandTheme === 'dark-modern',
    showFeatured: presentation.settings.showFeatured,
    showTags: presentation.settings.showTags,
    showAllergens: presentation.settings.showAllergens,
    showCurrencySymbol: presentation.settings.showCurrencySymbol,
    showLastUpdated: presentation.settings.showLastUpdated,
    isPhotoHeavy: brandTheme === 'photo-heavy',
  };
}

export type OnboardingFlags = {
  hasBusiness: boolean;
  hasPublishedMenu: boolean;
  hasQrCode: boolean;
  hasTeamMember: boolean;
};

export function computeOnboardingComplete(flags: OnboardingFlags): boolean {
  return flags.hasBusiness && flags.hasPublishedMenu && flags.hasQrCode && flags.hasTeamMember;
}

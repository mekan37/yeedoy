import React from 'react';
import { render, screen } from '@testing-library/react';
import { Button } from '@/src/ui/components/button';
import { describe, expect, test } from 'vitest';

describe('Button', () => {
  test('metni render eder', () => {
    render(<Button>Kaydet</Button>);
    expect(
      screen.getByRole('button', { name: 'Kaydet' }),
    ).toBeInTheDocument();
  });

  test('ozel className degerini birlestirir', () => {
    render(<Button className="w-full">Yayinla</Button>);
    expect(screen.getByRole('button', { name: 'Yayinla' })).toHaveClass(
      'w-full',
    );
  });
});

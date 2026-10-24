import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { describe, expect, it } from 'vitest';
import { App } from './App';

describe('landing page', () => {
  it('shows the booking CTA and core sections', () => {
    render(<MemoryRouter><App /></MemoryRouter>);
    expect(screen.getByRole('heading', { name: /good food/i })).toBeInTheDocument();
    expect(screen.getAllByRole('link', { name: /book a consultation/i }).length).toBeGreaterThan(0);
    expect(screen.getByText(/three easy steps/i)).toBeInTheDocument();
  });
});

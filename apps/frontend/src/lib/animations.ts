import { useEffect } from 'react';
import gsap from 'gsap';

export function animateScreenEntrance(containerElement: HTMLElement | null) {
  if (!containerElement) return;

  // Kill any existing tweens on this container
  gsap.killTweensOf(containerElement);
  gsap.killTweensOf(containerElement.querySelectorAll('.gsap-reveal'));

  // Main container fade & slide
  gsap.fromTo(
    containerElement,
    { opacity: 0, y: 12 },
    { opacity: 1, y: 0, duration: 0.35, ease: 'power2.out' }
  );

  // Stagger reveal on cards & key sections
  const cards = containerElement.querySelectorAll('.gsap-reveal');
  if (cards.length > 0) {
    gsap.fromTo(
      cards,
      { opacity: 0, y: 18 },
      {
        opacity: 1,
        y: 0,
        duration: 0.4,
        ease: 'power2.out',
        stagger: 0.05,
        delay: 0.05
      }
    );
  }
}

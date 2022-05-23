export default () => {
  const nuxtApp = useNuxtApp();

  return {
    gsap: nuxtApp.$gsap,
    ScrollTrigger: nuxtApp.$ScrollTrigger,
    ScrollToPlugin: nuxtApp.$ScrollToPlugin,
  };
};

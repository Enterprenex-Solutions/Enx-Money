/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  reactStrictMode: true,
  transpilePackages: ['@zerocarbonix/shared'],
};

module.exports = nextConfig;

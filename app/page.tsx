export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm">
        <h1 className="text-4xl font-bold text-center mb-4">
          Welcome to your Vercel app
        </h1>
        <p className="text-center text-gray-500 dark:text-gray-400 mb-8">
          Edit{' '}
          <code className="rounded bg-gray-100 px-2 py-1 font-mono text-sm dark:bg-gray-800">
            app/page.tsx
          </code>{' '}
          to get started.
        </p>
        <div className="flex justify-center gap-4">
          <a
            href="https://nextjs.org/docs"
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-lg border border-transparent px-5 py-2.5 text-sm font-medium transition-colors hover:border-gray-300 hover:bg-gray-100 dark:hover:border-gray-600 dark:hover:bg-gray-800"
          >
            Next.js Docs
          </a>
          <a
            href="https://vercel.com/new"
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-lg bg-black px-5 py-2.5 text-sm font-medium text-white transition-colors hover:bg-gray-800 dark:bg-white dark:text-black dark:hover:bg-gray-200"
          >
            Deploy to Vercel
          </a>
        </div>
      </div>
    </main>
  )
}

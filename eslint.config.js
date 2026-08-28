import js from '@eslint/js';

export default [
  js.configs.recommended,
  {
    ignores: ['build/**', '.dart_tool/**', 'node_modules/**', 'coverage/**', '.vercel/**'],
  },
  {
    files: ['**/*.{js,cjs,mjs}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        module: 'readonly',
        require: 'readonly',
        process: 'readonly',
        console: 'readonly',
      },
    },
    rules: {
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
      'no-console': 'warn',
      'prefer-const': 'error',
      'no-var': 'error',
      'curly': 'error',
      'eqeqeq': ['error', 'always'],
      'no-debugger': 'error',
      'no-eval': 'error',
    },
  },
];

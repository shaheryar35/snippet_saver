// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/snippet_saver_web.ex",
    "../lib/snippet_saver_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
        // Add your design system colors
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',  // Primary blue
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        secondary: {
          50: '#ecfdf5',
          100: '#d1fae5',
          200: '#a7f3d0',
          300: '#6ee7b7',
          400: '#34d399',
          500: '#10b981',  // Success green
          600: '#059669',
          700: '#047857',
          800: '#065f46',
          900: '#064e3b',
        },
        danger: {
          50: '#fef2f2',
          100: '#fee2e2',
          200: '#fecaca',
          300: '#fca5a5',
          400: '#f87171',
          500: '#ef4444',  // Danger red
          600: '#dc2626',
          700: '#b91c1c',
          800: '#991b1b',
          900: '#7f1d1d',
        },
        warning: {
          50: '#fffbeb',
          100: '#fef3c7',
          200: '#fde68a',
          300: '#fcd34d',
          400: '#fbbf24',
          500: '#f59e0b',  // Warning orange
          600: '#d97706',
          700: '#b45309',
          800: '#92400e',
          900: '#78350f',
        },
      },
      // Add custom spacing if needed
      spacing: {
        'form': '1.5rem',
        'card': '1.5rem',
      },
      // Add custom font sizes if needed
      fontSize: {
        'xxs': '0.625rem',
      },
      // Add custom border radius
      borderRadius: {
        'card': '0.75rem',
      },
      // Add custom animations
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-down': 'slideDown 0.2s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Custom plugin for button variants (optional)
    plugin(function({addComponents, theme}) {
      addComponents({
        '.btn-primary': {
          backgroundColor: theme('colors.primary.600'),
          color: 'white',
          padding: `${theme('spacing.2')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.lg'),
          fontWeight: theme('fontWeight.medium'),
          '&:hover': {
            backgroundColor: theme('colors.primary.700'),
          },
          '&:focus': {
            outline: 'none',
            ringWidth: '2px',
            ringColor: theme('colors.primary.500'),
            ringOffsetWidth: '2px',
          },
        },
        '.btn-danger': {
          backgroundColor: theme('colors.danger.500'),
          color: 'white',
          padding: `${theme('spacing.2')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.lg'),
          fontWeight: theme('fontWeight.medium'),
          '&:hover': {
            backgroundColor: theme('colors.danger.600'),
          },
        },
        '.card': {
          backgroundColor: 'white',
          borderRadius: theme('borderRadius.card'),
          padding: theme('spacing.card'),
          boxShadow: theme('boxShadow.md'),
        },
        '.input-field': {
          width: '100%',
          padding: `${theme('spacing.2')} ${theme('spacing.3')}`,
          borderWidth: '1px',
          borderColor: theme('colors.gray.300'),
          borderRadius: theme('borderRadius.lg'),
          '&:focus': {
            outline: 'none',
            ringWidth: '2px',
            ringColor: theme('colors.primary.500'),
            borderColor: theme('colors.primary.500'),
          },
        },
      })
    }),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, {values})
    })
  ]
}
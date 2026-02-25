# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Chartkick for analytics charts
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"

# SortableJS for kanban drag-and-drop
pin "sortablejs", to: "https://cdn.jsdelivr.net/npm/sortablejs@1.15.6/modular/sortable.esm.js"

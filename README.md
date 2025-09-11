# Personal Finance Tracker

A comprehensive Streamlit application for tracking personal finances with beautiful visualizations and easy-to-use interface.

## Features

### 📝 Data Entry
- Add transactions with date, type (Income/Expense), mode (Cash/Cheque), category, amount, and notes
- Smart category suggestions based on transaction type
- Data stored locally in CSV format

### 📊 Dashboard
- Monthly summary with total income, expenses, and balance
- Recent transactions display
- Clean metric cards with currency formatting

### 📈 Monthly Report
- Interactive Sankey diagram showing money flow
- Income sources → Total Income → Expense categories
- Bar charts for detailed breakdown by category
- Export functionality for monthly data

### 🎨 User Interface
- Clean and minimal design
- Sidebar for month selection
- Tabbed interface for easy navigation
- Responsive layout

## Installation

1. Clone or download this repository
2. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Usage

1. Run the Streamlit app:
   ```bash
   streamlit run app.py
   ```

2. Open your browser and navigate to the URL shown in the terminal (usually `http://localhost:8501`)

3. Start adding your transactions and explore the dashboard!

## File Structure

```
finance/
├── app.py              # Main Streamlit application
├── requirements.txt    # Python dependencies
├── README.md          # This file
└── transactions.csv   # Data file (created automatically)
```

## Data Storage

All transactions are stored in a local `transactions.csv` file with the following columns:
- Date: Transaction date
- Type: Income or Expense
- Mode: Cash or Cheque
- Category: Transaction category
- Amount: Transaction amount
- Notes: Optional notes

## Categories

### Income Categories
- Salary
- Freelance
- Investment
- Other Income

### Expense Categories
- Food
- Rent
- Utilities
- Transportation
- Entertainment
- Healthcare
- Shopping
- Savings
- Other Expense

## Features in Detail

### Sankey Diagram
The Sankey diagram provides a visual representation of money flow:
- Green flows represent income sources
- Red flows represent expense categories
- Flow width is proportional to the amount
- Shows the complete money journey from sources to expenses

### Export Functionality
- Export monthly transactions as CSV
- File naming includes year and month for easy organization
- Includes all transaction details

## Customization

You can easily customize the app by:
- Adding new categories in the `app.py` file
- Modifying the color scheme in the Sankey diagram
- Adding new visualization types
- Extending the data model

## Requirements

- Python 3.7+
- Streamlit
- Pandas
- Plotly

## License

This project is open source and available under the MIT License.

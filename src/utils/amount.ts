// Helpers for amount-entry TextInputs that should display with thousand
// separators while the user is typing.
//
// Component flow:
//   const [amount, setAmount] = useState('');   // raw, digits + optional '.'
//   <TextInput
//     value={formatAmountInput(amount)}
//     onChangeText={(t) => setAmount(parseAmountInput(t))}
//   />

// Drop commas + any non-digit / non-dot characters. Keeps a single decimal.
export function parseAmountInput(formatted: string): string {
    const cleaned = (formatted || '').replace(/,/g, '').replace(/[^0-9.]/g, '');
    const firstDot = cleaned.indexOf('.');
    if (firstDot === -1) return cleaned;
    // Strip any extra dots beyond the first.
    return cleaned.slice(0, firstDot + 1) + cleaned.slice(firstDot + 1).replace(/\./g, '');
}

// Group the integer part with commas, preserving a trailing dot or in-progress
// decimal so typing "1234." or "1234.5" stays correct.
export function formatAmountInput(raw: string): string {
    if (!raw) return '';
    const [intPart, decPart] = raw.split('.');
    const withCommas = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    if (raw.includes('.')) {
        return decPart !== undefined && decPart !== ''
            ? `${withCommas}.${decPart}`
            : `${withCommas}.`;
    }
    return withCommas;
}

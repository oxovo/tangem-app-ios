//
//  GroupedNumberTextField.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.11.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct GroupedNumberTextField: View {
    @Binding private var decimalValue: DecimalValue?
    @State private var textFieldText: String = ""

    private let placeholder: String = "0"
    private var groupedNumberFormatter: GroupedNumberFormatter
    private var decimalSeparator: Character { groupedNumberFormatter.decimalSeparator }
    private var groupingSeparator: String { groupedNumberFormatter.groupingSeparator }

    init(
        decimalValue: Binding<DecimalValue?>,
        groupedNumberFormatter: GroupedNumberFormatter
    ) {
        _decimalValue = decimalValue
        self.groupedNumberFormatter = groupedNumberFormatter
    }

    private var textFieldProxyBinding: Binding<String> {
        Binding<String>(
            get: { groupedNumberFormatter.format(from: textFieldText) },
            set: { updateValues(with: $0) }
        )
    }

    var body: some View {
        TextField(placeholder, text: textFieldProxyBinding)
            .style(Fonts.Regular.title1, color: Colors.Text.primary1)
            .keyboardType(.decimalPad)
            .tintCompat(Colors.Text.primary1)
            .onChange(of: decimalValue) { newDecimalValue in
                switch newDecimalValue {
                case .none, .internal:
                    // Do nothing. Because all internal values already updated
                    break
                case .external(let value):
                    // If the decimalValue did updated from external place
                    // We have to update the private values
                    let formattedNewValue = groupedNumberFormatter.format(from: value)
                    updateValues(with: formattedNewValue)
                }
            }
    }

    private func updateValues(with newValue: String) {
        // Remove space separators for formatter correct work
        var numberString = newValue.replacingOccurrences(of: groupingSeparator, with: "")

        // If user start enter number with `decimalSeparator` add zero before comma
        if numberString == String(decimalSeparator) {
            numberString.insert("0", at: numberString.startIndex)
        }

        // Continue if the field is empty. The field supports only decimal values
        guard numberString.isEmpty || Decimal(string: numberString) != nil else { return }

        // If user double tap on zero, add `decimalSeparator` to continue enter number
        if numberString == "00" {
            numberString.insert(decimalSeparator, at: numberString.index(before: numberString.endIndex))
        }

        // If text already have `decimalSeparator` remove last one
        if numberString.last == decimalSeparator,
           numberString.prefix(numberString.count - 1).contains(decimalSeparator) {
            numberString.removeLast()
        }

        // Update private `@State` for display not correct number, like 0,000
        textFieldText = numberString

        // Format string to reduce digits
        var formattedValue = groupedNumberFormatter.format(from: numberString)

        // Convert formatted string to correct decimal number
        formattedValue = formattedValue.replacingOccurrences(of: String(decimalSeparator), with: ".")
        formattedValue = formattedValue.replacingOccurrences(of: groupingSeparator, with: "")

        // We can't use here the NumberFormatter because it work with the NSNumber
        // And NSNumber is working wrong with ten zeros and one after decimalSeparator
        // Eg. NumberFormatter.number(from: "0.00000000001") will return "0.000000000009999999999999999"
        // Like is NSNumber(floatLiteral: 0.00000000001) will return "0.000000000009999999999999999"
        if let value = Decimal(string: formattedValue) {
            decimalValue = .internal(value)
        } else if numberString.isEmpty {
            decimalValue = nil
        }
    }
}

// MARK: - Setupable

extension GroupedNumberTextField: Setupable {
    func maximumFractionDigits(_ digits: Int) -> Self {
        map { $0.groupedNumberFormatter.update(maximumFractionDigits: digits) }
    }
}

struct GroupedNumberTextField_Previews: PreviewProvider {
    @State private static var decimalValue: GroupedNumberTextField.DecimalValue?

    static var previews: some View {
        GroupedNumberTextField(
            decimalValue: $decimalValue,
            groupedNumberFormatter: GroupedNumberFormatter(maximumFractionDigits: 8)
        )
    }
}

extension GroupedNumberTextField {
    enum DecimalValue: Hashable {
        case `internal`(Decimal)
        case external(Decimal)

        var value: Decimal {
            switch self {
            case .internal(let value):
                return value
            case .external(let value):
                return value
            }
        }

        var isInternal: Bool {
            switch self {
            case .internal:
                return true
            case .external:
                return false
            }
        }
    }
}

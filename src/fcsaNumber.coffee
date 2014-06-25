angular.module('fcsa-number', []).
directive 'fcsaNumber', ->
    
    isNumber = (val) ->
        !isNaN(parseFloat(val)) && isFinite(val)

    # 45 is '-', 57 is '9' and 47 is '/'
    isNotDigit = (which) ->
        (which < 45 || which > 57 || which is 47)

    hasMultipleDecimals = (val) ->
      val? && val.toString().split('.').length > 2

    makeMaxDecimals = (maxDecimals) ->
        if maxDecimals > 0
            regexString = "^-?\\d*\\.?\\d{0,#{maxDecimals}}$"
        else
            regexString = "^-?\\d*$"
        validRegex = new RegExp regexString

        (val) -> validRegex.test val
        
    makeMaxNumber = (maxNumber) ->
        (val, number) -> number <= maxNumber

    makeMinNumber = (minNumber) ->
        (val, number) -> number >= minNumber

    makeMaxDigits = (maxDigits) ->
        validRegex = new RegExp "^-?\\d{0,#{maxDigits}}(\\.\\d*)?$"
        (val) -> validRegex.test val

    makeIsValid = (options) ->
        validations = []
        
        if options.decimals?
            validations.push makeMaxDecimals options.decimals
        if options.max?
            validations.push makeMaxNumber options.max
        if options.min?
            validations.push makeMinNumber options.min
        if options.digits?
            validations.push makeMaxDigits options.digits
            
        (val) ->
            return true if val == '-'
            return false unless isNumber val
            return false if hasMultipleDecimals val
            number = Number val
            for i in [0...validations.length]
                return false unless validations[i] val, number
            true
        
    commasRegex = /,/g
    addCommasToInteger = (val) ->
        val.toString().replace /(\d)(?=(\d{3})+(?!\d))/g, '$1,'

    {
        restrict: 'A'
        require: 'ngModel'
        scope:
            options: '@fcsaNumber'
        link: (scope, elem, attrs, ngModelCtrl) ->
            options = {}
            if scope.options?
                options = scope.$eval scope.options

            isValid = makeIsValid options

            ngModelCtrl.$parsers.unshift (viewVal) ->
                if isValid(viewVal) || !viewVal
                    ngModelCtrl.$setValidity 'fcsaNumber', true
                    return viewVal
                else
                    ngModelCtrl.$setValidity 'fcsaNumber', false
                    return undefined

            ngModelCtrl.$formatters.push (val) ->
                if options.nullDisplay? && (!val || val == '')
                    return options.nullDisplay
                return val if !val? || !isValid val
                ngModelCtrl.$setValidity 'fcsaNumber', true
                addCommasToInteger val

            elem.on 'blur', ->
                viewValue = ngModelCtrl.$modelValue
                return if !viewValue? || !isValid(viewValue)
                for formatter in ngModelCtrl.$formatters
                    viewValue = formatter(viewValue)
                ngModelCtrl.$viewValue = viewValue
                ngModelCtrl.$render()

            elem.on 'focus', (e) ->
                target = $(e.target)
                val = target.val()
                target.val val.replace commasRegex, ''
                target.select()

            elem.on 'keypress', (e) ->
                e.preventDefault() if isNotDigit e.which
    }

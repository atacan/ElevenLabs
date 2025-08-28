#!/usr/bin/env node

// Run with `node generate_overlay.js`
const fs = require('fs');
const path = require('path');

// Read the OpenAPI spec
const openApiPath = path.join(__dirname, 'original.json');
const openApiSpec = JSON.parse(fs.readFileSync(openApiPath, 'utf8'));

// Function to recursively find all properties with anyOf containing null
function findNullableFields(obj, currentPath = []) {
    const nullableFields = [];
    
    if (typeof obj !== 'object' || obj === null) {
        return nullableFields;
    }
    
    // Check if current object has anyOf with null
    if (obj.anyOf && Array.isArray(obj.anyOf)) {
        const hasNull = obj.anyOf.some(item => item.type === 'null');
        if (hasNull) {
            // Create the non-null version
            const nonNullOptions = obj.anyOf.filter(item => item.type !== 'null');
            let newFieldDef;
            
            if (nonNullOptions.length === 1) {
                // If only one non-null option, use it directly
                newFieldDef = { ...nonNullOptions[0] };
            } else {
                // If multiple non-null options, keep as anyOf
                newFieldDef = { anyOf: nonNullOptions };
            }
            
            // Preserve other properties
            Object.keys(obj).forEach(key => {
                if (key !== 'anyOf') {
                    newFieldDef[key] = obj[key];
                }
            });
            
            nullableFields.push({
                path: currentPath.join('.'),
                jsonPath: '$.' + currentPath.join('.'),
                originalDef: obj,
                newDef: newFieldDef
            });
        }
    }
    
    // Recursively search in nested objects
    for (const [key, value] of Object.entries(obj)) {
        if (typeof value === 'object' && value !== null) {
            nullableFields.push(...findNullableFields(value, [...currentPath, key]));
        }
    }
    
    return nullableFields;
}

// Function to find nullable fields in path parameters
function findNullableParameterFields(paths) {
    const nullableFields = [];
    
    for (const [pathName, pathObj] of Object.entries(paths)) {
        for (const [method, methodObj] of Object.entries(pathObj)) {
            if (methodObj.parameters && Array.isArray(methodObj.parameters)) {
                methodObj.parameters.forEach((param, paramIndex) => {
                    if (param.schema) {
                        const currentPath = ['paths', pathName, method, 'parameters', paramIndex.toString(), 'schema'];
                        const paramNullableFields = findNullableFields(param.schema, currentPath);
                        nullableFields.push(...paramNullableFields);
                    }
                });
            }
        }
    }
    
    return nullableFields;
}

// Find all nullable fields in components.schemas and path parameters
console.log('Scanning OpenAPI spec for nullable fields...');
const schemaNullableFields = findNullableFields(openApiSpec.components?.schemas || {}, ['components', 'schemas']);
const parameterNullableFields = findNullableParameterFields(openApiSpec.paths || {});
const nullableFields = [...schemaNullableFields, ...parameterNullableFields];

console.log(`Found ${nullableFields.length} nullable fields:`);
nullableFields.forEach(field => {
    console.log(`  - ${field.path}`);
});

// Generate overlay actions
const overlayActions = [];

nullableFields.forEach(field => {
    // Add remove action
    overlayActions.push({
        target: field.jsonPath,
        remove: true
    });
    
    // Add update action
    const pathParts = field.path.split('.');
    const propertyName = pathParts.pop(); // Remove the last part (property name)
    const parentPath = '$.' + pathParts.join('.');
    
    overlayActions.push({
        target: parentPath,
        update: {
            [propertyName]: field.newDef
        }
    });
});

// Create the complete overlay
const overlay = {
    "overlay": "1.0.0",
    "info": {
        "title": "Fix OpenAPI spec - Remove null options from anyOf fields",
        "version": "1.0.2"
    },
    "actions": overlayActions
};

// Write the overlay file
const overlayPath = path.join(__dirname, 'overlay_generated_for_anyof_type_null.json');
fs.writeFileSync(overlayPath, JSON.stringify(overlay, null, 2));

console.log(`\nGenerated overlay with ${overlayActions.length} actions`);
console.log(`Overlay saved to: ${overlayPath}`);
console.log('\nSample of generated actions:');
console.log(JSON.stringify(overlay.actions.slice(0, 4), null, 2));
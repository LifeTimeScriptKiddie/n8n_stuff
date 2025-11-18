#!/usr/bin/env node

/**
 * Scope Validator for n8n Red Team Reconnaissance Hub
 *
 * This script validates if a target is within the authorized scope
 * for red team operations. It can be called from n8n workflows or CLI.
 *
 * Usage:
 *   node scope-validator.js <target> <scope_file.json>
 *   node scope-validator.js api.example.com scopes/example_scope.json
 *
 * Exit codes:
 *   0 = Target is in scope
 *   1 = Target is out of scope
 *   2 = Error (invalid scope file, missing arguments, etc.)
 */

const fs = require('fs');
const { isIP } = require('net');

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  if (process.env.NODE_ENV !== 'test') {
    console.log(`${colors[color]}${message}${colors.reset}`);
  }
}

/**
 * Normalize a target to lowercase and remove protocol/path
 */
function normalizeTarget(target) {
  target = target.toLowerCase().trim();

  // Remove protocol
  target = target.replace(/^https?:\/\//, '');

  // Remove port
  target = target.replace(/:[0-9]+$/, '');

  // Remove path
  target = target.split('/')[0];

  return target;
}

/**
 * Check if target matches a wildcard pattern
 * Supports patterns like: *.example.com, *.internal, etc.
 */
function matchesWildcard(target, pattern) {
  // Convert wildcard pattern to regex
  const regexPattern = pattern
    .replace(/\./g, '\\.')           // Escape dots
    .replace(/\*/g, '[a-zA-Z0-9.-]+'); // Replace * with domain chars

  const regex = new RegExp(`^${regexPattern}$`, 'i');
  return regex.test(target);
}

/**
 * Check if IP is in CIDR range
 */
function isIPInCIDR(ip, cidr) {
  // Basic CIDR check - for production, use a proper library like 'ip-cidr'
  if (!cidr.includes('/')) {
    // Exact IP match
    return ip === cidr;
  }

  const [network, bits] = cidr.split('/');
  const mask = ~((1 << (32 - parseInt(bits))) - 1);

  const ipInt = ipToInt(ip);
  const networkInt = ipToInt(network);

  return (ipInt & mask) === (networkInt & mask);
}

/**
 * Convert IP address to integer
 */
function ipToInt(ip) {
  return ip.split('.').reduce((int, octet) => (int << 8) + parseInt(octet), 0) >>> 0;
}

/**
 * Check if target is within scope
 */
function isInScope(target, scopeDef) {
  target = normalizeTarget(target);

  // Check out_of_scope first (blacklist takes precedence)
  if (scopeDef.out_of_scope && scopeDef.out_of_scope.length > 0) {
    for (const pattern of scopeDef.out_of_scope) {
      if (matchesWildcard(target, pattern.toLowerCase())) {
        return {
          allowed: false,
          reason: `Target matches out-of-scope pattern: ${pattern}`,
          pattern: pattern
        };
      }

      // Check if target is an IP and matches out-of-scope CIDR
      if (isIP(target) && pattern.includes('/')) {
        if (isIPInCIDR(target, pattern)) {
          return {
            allowed: false,
            reason: `IP is in out-of-scope range: ${pattern}`,
            pattern: pattern
          };
        }
      }
    }
  }

  // Check in_scope (whitelist)
  for (const pattern of scopeDef.in_scope) {
    // Wildcard domain matching
    if (matchesWildcard(target, pattern.toLowerCase())) {
      return {
        allowed: true,
        reason: `Target matches in-scope pattern: ${pattern}`,
        pattern: pattern
      };
    }

    // IP/CIDR matching
    if (isIP(target)) {
      if (pattern.includes('/')) {
        // CIDR range
        if (isIPInCIDR(target, pattern)) {
          return {
            allowed: true,
            reason: `IP is in authorized CIDR range: ${pattern}`,
            pattern: pattern
          };
        }
      } else if (isIP(pattern)) {
        // Exact IP match
        if (target === pattern) {
          return {
            allowed: true,
            reason: `Exact IP match: ${pattern}`,
            pattern: pattern
          };
        }
      }
    }
  }

  return {
    allowed: false,
    reason: 'Target does not match any in-scope pattern',
    pattern: null
  };
}

/**
 * Check if current time is within allowed hours
 */
function isWithinAllowedHours(scopeDef) {
  if (!scopeDef.rules || !scopeDef.rules.allowed_hours) {
    return { allowed: true, reason: 'No time restrictions' };
  }

  const rules = scopeDef.rules.allowed_hours;
  const now = new Date();

  // Check day of week
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const currentDay = days[now.getDay()];

  if (rules.days && !rules.days.includes(currentDay)) {
    return {
      allowed: false,
      reason: `Scanning not allowed on ${currentDay}. Allowed days: ${rules.days.join(', ')}`
    };
  }

  // Check time range
  if (rules.start_time && rules.end_time) {
    const [startHour, startMin] = rules.start_time.split(':').map(Number);
    const [endHour, endMin] = rules.end_time.split(':').map(Number);

    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const startMinutes = startHour * 60 + startMin;
    const endMinutes = endHour * 60 + endMin;

    if (currentMinutes < startMinutes || currentMinutes > endMinutes) {
      return {
        allowed: false,
        reason: `Scanning only allowed between ${rules.start_time} and ${rules.end_time} (${rules.timezone || 'UTC'})`
      };
    }
  }

  return { allowed: true, reason: 'Within allowed time window' };
}

/**
 * Check if authorization has expired
 */
function isAuthorizationValid(scopeDef) {
  if (!scopeDef.authorization || !scopeDef.authorization.expiry_date) {
    return { valid: true, reason: 'No expiry date set' };
  }

  const expiryDate = new Date(scopeDef.authorization.expiry_date);
  const now = new Date();

  if (now > expiryDate) {
    return {
      valid: false,
      reason: `Authorization expired on ${scopeDef.authorization.expiry_date}`
    };
  }

  // Warn if expiring soon (within 7 days)
  const daysUntilExpiry = Math.ceil((expiryDate - now) / (1000 * 60 * 60 * 24));
  if (daysUntilExpiry <= 7) {
    return {
      valid: true,
      reason: `Authorization expires in ${daysUntilExpiry} days`,
      warning: true
    };
  }

  return { valid: true, reason: 'Authorization is valid' };
}

/**
 * Main validation function
 */
function validateTarget(target, scopeFilePath) {
  // Load scope definition
  let scopeDef;
  try {
    const scopeData = fs.readFileSync(scopeFilePath, 'utf8');
    scopeDef = JSON.parse(scopeData);
  } catch (error) {
    return {
      success: false,
      error: `Failed to load scope file: ${error.message}`
    };
  }

  // Validate scope structure
  if (!scopeDef.scope_name || !scopeDef.in_scope || !scopeDef.authorization) {
    return {
      success: false,
      error: 'Invalid scope file: missing required fields (scope_name, in_scope, authorization)'
    };
  }

  // Check authorization validity
  const authCheck = isAuthorizationValid(scopeDef);
  if (!authCheck.valid) {
    return {
      success: false,
      allowed: false,
      reason: authCheck.reason,
      scope_name: scopeDef.scope_name
    };
  }

  // Check allowed hours
  const timeCheck = isWithinAllowedHours(scopeDef);
  if (!timeCheck.allowed) {
    return {
      success: false,
      allowed: false,
      reason: timeCheck.reason,
      scope_name: scopeDef.scope_name
    };
  }

  // Check if target is in scope
  const scopeCheck = isInScope(target, scopeDef);

  return {
    success: true,
    allowed: scopeCheck.allowed,
    reason: scopeCheck.reason,
    pattern: scopeCheck.pattern,
    scope_name: scopeDef.scope_name,
    engagement_type: scopeDef.authorization.engagement_type,
    stealth_level: scopeDef.rules?.stealth_level || 'medium',
    rate_limit: scopeDef.rules?.rate_limit_per_sec || 10,
    authorization_warning: authCheck.warning ? authCheck.reason : null
  };
}

/**
 * CLI entry point
 */
function main() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    log('Usage: node scope-validator.js <target> <scope_file.json>', 'red');
    log('', 'reset');
    log('Example:', 'cyan');
    log('  node scope-validator.js api.example.com scopes/example_scope.json', 'reset');
    process.exit(2);
  }

  const [target, scopeFile] = args;

  log('═══════════════════════════════════════════════════════════', 'blue');
  log('  Red Team Scope Validator', 'blue');
  log('═══════════════════════════════════════════════════════════', 'blue');
  log('', 'reset');
  log(`Target:      ${target}`, 'cyan');
  log(`Scope File:  ${scopeFile}`, 'cyan');
  log('', 'reset');

  const result = validateTarget(target, scopeFile);

  if (!result.success) {
    log(`✗ ERROR: ${result.error}`, 'red');
    log('', 'reset');
    process.exit(2);
  }

  log(`Scope:       ${result.scope_name}`, 'cyan');
  log(`Type:        ${result.engagement_type || 'N/A'}`, 'cyan');
  log('', 'reset');

  if (result.authorization_warning) {
    log(`⚠ WARNING: ${result.authorization_warning}`, 'yellow');
    log('', 'reset');
  }

  if (result.allowed) {
    log('✓ AUTHORIZED', 'green');
    log(`  Reason: ${result.reason}`, 'green');
    if (result.pattern) {
      log(`  Matched Pattern: ${result.pattern}`, 'green');
    }
    log(`  Stealth Level: ${result.stealth_level}`, 'cyan');
    log(`  Rate Limit: ${result.rate_limit} req/sec`, 'cyan');
    log('', 'reset');
    log('You may proceed with reconnaissance.', 'green');
    process.exit(0);
  } else {
    log('✗ UNAUTHORIZED', 'red');
    log(`  Reason: ${result.reason}`, 'red');
    log('', 'reset');
    log('⚠ WARNING: Scanning this target is NOT AUTHORIZED!', 'yellow');
    log('Proceeding could violate laws and regulations.', 'yellow');
    process.exit(1);
  }
}

// Export functions for use in n8n workflows
if (require.main === module) {
  main();
} else {
  module.exports = {
    validateTarget,
    isInScope,
    isWithinAllowedHours,
    isAuthorizationValid,
    normalizeTarget
  };
}
